# Dear Diary...

A simple personal diary web application built with Spring Boot for practicing full-stack Java web development. This repository is prepared as a portfolio project to showcase back-end development with Spring Boot, data persistence with JPA, server-rendered UI with Thymeleaf, and MySQL integration.

## What it contains

- A Spring Boot web application (Java 17).
- User registration, login, and password reset flows (basic session-based auth handled via an interceptor).
- CRUD for diary entries (create, read, update, delete) with a simple UI.
- Thymeleaf templates for server-side rendering under `src/main/resources/templates`.
- Static CSS under `src/main/resources/static/css`.
- JPA entities for `User` and `Diary` and Spring Data JPA repositories.
- Simple service layer separating business logic from controllers.

## Key features

- User registration and authentication (password hashing using Spring Security Crypto).
- Session-based authentication enforced with an interceptor (`SessionAuthInterceptor`).
- Diary CRUD operations, with a dashboard, entry form, and single-entry view.
- Server-side validation using Spring Validation.
- Configurable via `application.properties` (JDBC URL, credentials, JPA settings).

## Tech stack & libraries

- Language: Java 17
- Framework: Spring Boot 3.5.7
- Templating: Thymeleaf (spring-boot-starter-thymeleaf)
- Web: Spring MVC (spring-boot-starter-web)
- Persistence: Spring Data JPA (spring-boot-starter-data-jpa) + Hibernate
- Database: MySQL (mysql-connector-j)
- Validation: spring-boot-starter-validation (Jakarta Validation)
- Security (crypto only): spring-security-crypto (for password hashing)
- Developer tools: spring-boot-devtools (runtime, optional)
- Build: Maven (wrapper included: `mvnw` / `mvnw.cmd`)

## Project structure (high level)

- src/main/java/com/practice/dailydiary
  - controller/     (MVC controllers)
  - model/          (JPA entities: User, Diary)
  - repository/     (Spring Data JPA repositories)
  - service/        (service interfaces)
  - serviceImpl/    (service implementations)
  - config/         (Web configuration & session interceptor)
- src/main/resources
  - templates/      (Thymeleaf HTML templates)
  - static/         (CSS and other static assets)
  - application.properties

## Version

November 20th, 2025
Version 1.0.0 - Initial release.

## License

This repository is a personal project for portfolio purposes.
