CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    course VARCHAR(100),
    year_level VARCHAR(50),
    section VARCHAR(50),
    department VARCHAR(100),
    college VARCHAR(100),
    contact_number VARCHAR(20),
    address TEXT,
    qr_code_data TEXT,
    role VARCHAR(50) NOT NULL DEFAULT 'student',
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE password_resets (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used BOOLEAN DEFAULT FALSE
);

-- Create indexes
CREATE INDEX idx_password_resets_email ON password_resets(email);
CREATE INDEX idx_password_resets_code ON password_resets(code);

CREATE TABLE pending_users (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    course VARCHAR(100),
    year_level VARCHAR(10),
    section VARCHAR(50),
    department VARCHAR(100),
    college VARCHAR(100),
    contact_number VARCHAR(20),
    address TEXT,
    verification_code VARCHAR(6) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);




ALTER TABLE users
ADD CONSTRAINT uni_users_student_id UNIQUE (student_id);

ALTER TABLE users
ADD CONSTRAINT uni_users_email UNIQUE (email);