package models

import "time"

type ReceptionStatus string

const (
	InProgress ReceptionStatus = "in_progress"
	Closed     ReceptionStatus = "close"
)

type Reception struct {
	ID        string          `json:"id"`
	DateTime  time.Time       `json:"dateTime"`
	PVZID     string          `json:"pvzId"`
	Status    ReceptionStatus `json:"status"`
	CreatedAt time.Time       `json:"-"`
	UpdatedAt time.Time       `json:"-"`
}
