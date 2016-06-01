package clients

type BmpClient interface {
	ConfigPath() string

	Info() (InfoResponse, error)
	Bms(deploymentName string) (BmsResponse, error)
	SlPackages() (SlPackagesResponse, error)
	Stemcells() (StemcellsResponse, error)
	SlPackageOptions(packageId string) (SlPackageOptionsResponse, error)
	TaskOutput(taskId uint, level string) (TaskOutputResponse, error)
	TaskJsonOutput(taskId uint, level string) (TaskJsonResponse, error)
	Tasks(latest uint) (TasksResponse, error)
	UpdateState(serverId string, status string) (UpdateStateResponse, error)
	Login(username string, password string) (LoginResponse, error)
	CreateBaremetal(createBaremetalInfo CreateBaremetalInfo, dryRun bool) (CreateBaremetalResponse, error)
	ProvisioningBaremetal(createBaremetalInfo CreateBaremetalInfo) (CreateBaremetalResponse, error)
}
