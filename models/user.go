package models

import (
	"time"
)

// User defines the database table for authenticated users
type User struct {
	ID           string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Username     string    `gorm:"column:username;unique;not null" json:"username"`
	PasswordHash string    `gorm:"column:password_hash;not null" json:"-"`
	IsAdmin      bool      `gorm:"column:is_admin;default:false;not null" json:"is_admin"`
	CreatedAt    time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt    time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (User) TableName() string {
	return "users"
}
