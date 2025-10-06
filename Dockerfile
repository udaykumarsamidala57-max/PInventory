# Use official Tomcat with Java 17
FROM tomcat:9.0-jdk17

# Remove default apps (optional, keeps Tomcat clean)
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy your WAR into Tomcat webapps
COPY target/PInventory-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

# Expose port 8080
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]