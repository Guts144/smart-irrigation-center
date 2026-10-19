# Windows PowerShell script to run the backend in dev mode
$env:SPRING_PROFILES_ACTIVE = "dev,local"
mvn spring-boot:run
