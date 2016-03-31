package clients

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"

	slclient "github.com/maximilien/softlayer-go/client"
	slcommon "github.com/maximilien/softlayer-go/common"
	softlayer "github.com/maximilien/softlayer-go/softlayer"
)

type bmpClient struct {
	username   string
	password   string
	url        string
	httpClient softlayer.HttpClient
}

func NewBmpClient(username, password, url string, hClient softlayer.HttpClient) *bmpClient {
	var httpClient softlayer.HttpClient
	if hClient == nil {
		httpClient = slclient.NewHttpClient(username, password, url, "")
	} else {
		httpClient = hClient
	}

	return &bmpClient{
		username:   username,
		password:   password,
		url:        url,
		httpClient: httpClient,
	}
}

func (bc *bmpClient) Info() (InfoResponse, error) {
	path := fmt.Sprintf("%s/%s", bc.url, "info")
	responseBytes, errorCode, err := bc.httpClient.DoRawHttpRequest(path, "GET", &bytes.Buffer{})
	if err != nil {
		errorMessage := fmt.Sprintf("bmp: could not calls /info on BMP server, error message '%s'", err.Error())
		return InfoResponse{}, errors.New(errorMessage)
	}

	if slcommon.IsHttpErrorCode(errorCode) {
		errorMessage := fmt.Sprintf("bmp: could not call /info on BMP server, HTTP error code: '%d'", errorCode)
		return InfoResponse{}, errors.New(errorMessage)
	}

	infoResponse := InfoResponse{}
	err = json.Unmarshal(responseBytes, &infoResponse)
	if err != nil {
		errorMessage := fmt.Sprintf("bmp: failed to decode JSON response, err message '%s'", err.Error())
		err := errors.New(errorMessage)
		return InfoResponse{}, err
	}

	return infoResponse, nil
}
