package models

type PVZWithReceptions struct {
	PVZ        PVZ                    `json:"pvz"`
	Receptions []ReceptionWithProducts `json:"receptions"`
}

type ReceptionWithProducts struct {
	Reception Reception `json:"reception"`
	Products  []Product `json:"products"`
}

type ErrorResponse struct {
	Message string `json:"message"`
}
