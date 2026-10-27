CREATE DATABASE IF NOT EXISTS maritim_service
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE maritim_service;

CREATE TABLE IF NOT EXISTS admins (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vessels (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vessel_name VARCHAR(150) NOT NULL,
    vessel_type ENUM(
        'Tug Boat',
        'Offshore Support Vessel',
        'Crew Boat',
        'Landing Craft Tank',
        'Other'
    ) NOT NULL,
    capacity VARCHAR(100),
    location VARCHAR(150),
    daily_rate DECIMAL(15,2) DEFAULT NULL,
    description TEXT,
    image_path VARCHAR(255),
    status ENUM('Available', 'Maintenance', 'Inactive')
        NOT NULL DEFAULT 'Available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    company VARCHAR(150),
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS charter_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    request_code VARCHAR(30) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL,
    vessel_id BIGINT NOT NULL,
    operation_location VARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    duration_days INT NOT NULL,
    requirements TEXT,
    status ENUM(
        'Pending',
        'Reviewed',
        'Approved',
        'Rejected',
        'Completed'
    ) NOT NULL DEFAULT 'Pending',
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_request_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id),

    CONSTRAINT fk_request_vessel
        FOREIGN KEY (vessel_id) REFERENCES vessels(id)
);

CREATE INDEX idx_vessels_status ON vessels(status);
CREATE INDEX idx_requests_status ON charter_requests(status);
CREATE INDEX idx_requests_start_date ON charter_requests(start_date);
