package models

import "time"

type ProductType string

const (
	Electronics ProductType = "электроника"
	Clothing    ProductType = "одежда"
	Shoes       ProductType = "обувь"
)

type Product struct {
	ID          string      `json:"id"`
	DateTime    time.Time   `json:"dateTime"`
	Type        ProductType `json:"type"`
	ReceptionID string      `json:"receptionId"`
	Quantity    int         `json:"-"`
	CreatedAt   time.Time   `json:"-"`
	UpdatedAt   time.Time   `json:"-"`
}
