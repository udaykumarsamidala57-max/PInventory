# Use Tomcat 9 (suitable for javax.servlet.*)
FROM tomcat:9.0-jdk17-temurin

# Remove the default ROOT application
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copy your WAR file into Tomcat's webapps folder
COPY PInventory.war /usr/local/tomcat/webapps/ROOT.war

# Expose the Railway port
EXPOSE 8080

# Start Tomcat — note: Railway sets PORT env var automatically
CMD ["sh", "-c", "catalina.sh run"]