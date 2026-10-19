Set-Location 'C:\Users\Guts\Desktop\smart-irrigation-center\backend'
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot'
$env:SPRING_PROFILES_ACTIVE = 'dev,local'
& 'C:\Program Files\maven\apache-maven-3.9.16\bin\mvn.cmd' spring-boot:run
