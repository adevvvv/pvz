package models

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type CreatePVZRequest struct {
	City CityEnum `json:"city"`
}

type CreateReceptionRequest struct {
	PVZID string `json:"pvzId"`
}

type AddProductRequest struct {
	Type  ProductType `json:"type"`
	PVZID string      `json:"pvzId"`
}
