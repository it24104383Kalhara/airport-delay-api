package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"airport-delay-api/controllers"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// DB is a global variable to hold our database connection pool
var DB *gorm.DB

func main() {
	// 1. Load the .env file
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: No .env file found or error loading it")
	}

	// 2. Connect to the Database
	dsn := os.Getenv("DB_URL")
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to the database! \n", err)
	}
	fmt.Println("✅ Successfully connected to Supabase PostgreSQL!")

	// 3. Initialize the Gin Router
	router := gin.Default()

	// Initialize the controller with DB connection
	alertController := controllers.NewAlertController(DB)

	// 4. Create a simple health check route
	router.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "pong! Airport API is running.",
		})
	})

	// CRUD API routes
	api := router.Group("/api")
	{
		api.GET("/alerts", alertController.GetAlerts)
		api.GET("/alerts/:id", alertController.GetAlertByID)
		api.POST("/alerts", alertController.CreateAlert)
		api.PUT("/alerts/:id", alertController.UpdateAlert)
		api.DELETE("/alerts/:id", alertController.DeleteAlert)
	}

	// 5. Start the server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	fmt.Println("🚀 Server running on port:", port)
	router.Run(":" + port)
}