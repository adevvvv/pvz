package models

import "time"

type CityEnum string

const (
	Moscow          CityEnum = "Москва"
	SaintPetersburg CityEnum = "Санкт-Петербург"
	Kazan           CityEnum = "Казань"
)

type PVZ struct {
	ID               string    `json:"id"`
	RegistrationDate time.Time `json:"registrationDate"`
	City             CityEnum  `json:"city"`
}
