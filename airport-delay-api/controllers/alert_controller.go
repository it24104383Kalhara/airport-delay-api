package controllers

import (
	"net/http"
	"time"

	"airport-delay-api/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AlertController struct {
	DB *gorm.DB
}

func NewAlertController(db *gorm.DB) *AlertController {
	return &AlertController{DB: db}
}

// 1. READ ALL - GET /api/alerts
func (ac *AlertController) GetAlerts(c *gin.Context) {
	var alerts []models.FlightDelayAlert
	
	// Fetch alerts that are not archived, ordered by latest
	result := ac.DB.Where("status != ?", "ARCHIVED").Order("created_at desc").Find(&alerts)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, alerts)
}

// 2. READ ONE - GET /api/alerts/:id
func (ac *AlertController) GetAlertByID(c *gin.Context) {
	id := c.Param("id")
	var alert models.FlightDelayAlert

	if err := ac.DB.First(&alert, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert record not found"})
		return
	}

	c.JSON(http.StatusOK, alert)
}

// 3. CREATE - POST /api/alerts
func (ac *AlertController) CreateAlert(c *gin.Context) {
	var input models.FlightDelayAlert

	// Bind incoming JSON to struct and validate required fields
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Business rule check: new departure must be after original departure
	if input.NewDeparture.Before(input.OriginalDeparture) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "New departure time must be after original departure time"})
		return
	}

	input.CreatedAt = time.Now()
	input.UpdatedAt = time.Now()

	if err := ac.DB.Create(&input).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, input)
}

// 4. UPDATE - PUT /api/alerts/:id
func (ac *AlertController) UpdateAlert(c *gin.Context) {
	id := c.Param("id")
	var alert models.FlightDelayAlert

	// Check if record exists
	if err := ac.DB.First(&alert, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert record not found"})
		return
	}

	var input models.FlightDelayAlert
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update record fields
	ac.DB.Model(&alert).Updates(map[string]interface{}{
		"flight_number":      input.FlightNumber,
		"airline":            input.Airline,
		"destination":        input.Destination,
		"terminal_zone":      input.TerminalZone,
		"original_departure": input.OriginalDeparture,
		"new_departure":      input.NewDeparture,
		"delay_reason":       input.DelayReason,
		"severity_level":     input.SeverityLevel,
		"status":             input.Status,
		"updated_at":         time.Now(),
	})

	c.JSON(http.StatusOK, alert)
}

// 5. DELETE (Soft Delete/Archive) - DELETE /api/alerts/:id
func (ac *AlertController) DeleteAlert(c *gin.Context) {
	id := c.Param("id")
	var alert models.FlightDelayAlert

	if err := ac.DB.First(&alert, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert record not found"})
		return
	}

	// Aviation compliance rule: Soft delete by setting status to ARCHIVED
	ac.DB.Model(&alert).Update("status", "ARCHIVED")

	c.JSON(http.StatusOK, gin.H{"message": "Alert archived successfully"})
}