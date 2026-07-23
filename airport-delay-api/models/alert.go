package models

import (
	"time"
)

// FlightDelayAlert defines the database table structure and JSON format
type FlightDelayAlert struct {
	ID                string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	FlightNumber      string    `gorm:"column:flight_number;not null" json:"flight_number" binding:"required"`
	Airline           string    `gorm:"column:airline;not null" json:"airline" binding:"required"`
	Destination       string    `gorm:"column:destination;not null" json:"destination" binding:"required"`
	TerminalZone      string    `gorm:"column:terminal_zone;not null" json:"terminal_zone" binding:"required"`
	OriginalDeparture time.Time `gorm:"column:original_departure;not null" json:"original_departure" binding:"required"`
	NewDeparture      time.Time `gorm:"column:new_departure;not null" json:"new_departure" binding:"required"`
	DelayReason       string    `gorm:"column:delay_reason;not null" json:"delay_reason" binding:"required"`
	SeverityLevel     string    `gorm:"column:severity_level;default:'MEDIUM'" json:"severity_level"`
	Status            string    `gorm:"column:status;default:'ACTIVE'" json:"status"`
	CreatedAt         time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt         time.Time `gorm:"column:updated_at" json:"updated_at"`
}

// TableName explicitly points GORM to our Supabase table name
func (FlightDelayAlert) TableName() string {
	return "flight_delay_alerts"
}