import java.sql.*;
import java.util.UUID;

public class get_token {
    public static void main(String[] args) throws Exception {
        Class.forName("org.h2.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:h2:file:./backend/data/aquasense;AUTO_SERVER=TRUE", "sa", "")) {
            long userId = -1;
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT id FROM users WHERE email = 'mohamed.ghaesalli@esprit.tn' LIMIT 1")) {
                if (rs.next()) {
                    userId = rs.getLong(1);
                    System.out.println("USER ID: " + userId);
                } else {
                    System.out.println("USER NOT FOUND IN DB");
                    return;
                }
            }
            
            // Generate a token
            String token = UUID.randomUUID().toString();
            
            // Insert session
            try (PreparedStatement pt = conn.prepareStatement(
                "INSERT INTO tracking_sessions (tracking_token, customer_id, technician_name, status, started_at) VALUES (?, ?, 'Test Tech', 'ACTIVE', CURRENT_TIMESTAMP)")) {
                pt.setString(1, token);
                pt.setLong(2, userId);
                pt.executeUpdate();
                System.out.println("CREATED NEW SESSION WITH TOKEN: " + token);
            }
        }
    }
}
