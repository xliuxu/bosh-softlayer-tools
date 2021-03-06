#!/usr/bin/env bash
set -x -e
source bosh-softlayer-tools/ci/tasks/utils.sh

check_param deploy_name
check_param data_center_name
check_param private_vlan_id
check_param public_vlan_id

deployment_dir="${PWD}/deployment"
mkdir -p $deployment_dir
tar -zxvf director-artifacts-updated/director_artifacts_updated.tgz -C ${deployment_dir}
tar -zxvf cf-artifacts/cf_artifacts.tgz -C ${deployment_dir}

cat ${deployment_dir}/director-hosts >> /etc/hosts
${deployment_dir}/bosh-cli* -e $(cat ${deployment_dir}/director-hosts |awk '{print $2}') --ca-cert <(${deployment_dir}/bosh-cli* int ${deployment_dir}/credentials.yml --path /DIRECTOR_SSL/ca ) alias-env bosh-test 

director_password=$(${deployment_dir}/bosh-cli* int ${deployment_dir}/credentials.yml --path /DI_ADMIN_PASSWORD)
echo "Trying to login to director..."
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=${director_password}
${deployment_dir}/bosh-cli* -e bosh-test login

director_ip=$(awk '{print $1}' ${deployment_dir}/director-hosts)
director_uuid=$(grep -Po '(?<=director_id": ")[^"]*' ${deployment_dir}/director-deploy-state.json)

print_title  "Ensure cf is base version..."

# deploy base version of cf
${deployment_dir}/bosh-cli* -n -e bosh-test -d ${deploy_name} deploy ${deployment_dir}/cf-deploy-base.yml


# generate new cf deployment yml file for update
${deployment_dir}/bosh-cli* interpolate cf-template/${cf_template} \
							-v director_password=${director_password} \
							-v director_ip=${director_ip}\
							-v director_pub_ip=${director_ip}\
							-v director_uuid=${director_uuid}\
							-v deploy_name=${deploy_name}\
							-v data_center_name=${data_center_name}\
							-v private_vlan_id=${private_vlan_id}\
							-v public_vlan_id=${public_vlan_id}\
							-v stemcell_version=\"${stemcell_version}\"\
						    -v stemcell_location=${stemcell_location}\
							-v stemcell_name=${stemcell_name}\
							-v cf-release=${cf_release}\
							-v cf-release-version=${cf_release_version}\
						    > ${deployment_dir}/cf-deploy-update.yml

releases=$(${deployment_dir}/bosh-cli* int ${deployment_dir}/cf-deploy-update.yml --path /releases |grep -Po '(?<=- location: ).*')

# upload releases
while IFS= read -r line; do
${deployment_dir}/bosh-cli* -e bosh-test upload-release $line
done <<< "$releases"

function stemcell_exist(){
	stemcell_version=$1
	uploaded_stemcells=$(${deployment_dir}/bosh-cli*  -e bosh-test stemcells |awk '{print $2}'|sed s/[+*]$//)
	IFS= read -r -a stemcells<<<"$uploaded_stemcells"
	for stemcell in "$stemcells"
	do
		if [ "$stemcell_version" == "$stemcell" ];then
			return 0
		fi
	done
	return 1
}

if ! stemcell_exist ${stemcell_version}; then
	${deployment_dir}/bosh-cli* -e bosh-test upload-stemcell ${stemcell_location}
fi

print_title "Updating CF..."

${deployment_dir}/bosh-cli* -n -e bosh-test -d ${deploy_name} deploy ${deployment_dir}/cf-deploy-update.yml --no-redact

cp ${deployment_dir}/cf-deploy-update.yml  cf-artifacts/cf-deploy-update.yml

pushd cf-artifacts
   tar -zcvf  /tmp/cf_artifacts_updated.tgz ./ >/dev/null 2>&1
popd

mv /tmp/cf_artifacts_updated.tgz ./cf-artifacts-updated/

