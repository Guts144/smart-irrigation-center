package com.smartirrigation.util;

import com.smartirrigation.model.ValveAction;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

public class CsvExporter {

    public static void exportValveHistory(List<ValveAction> history, String filePath) throws IOException {
        try (FileWriter writer = new FileWriter(filePath)) {
            writer.append("ID,User ID,Action,Timestamp\n");
            
            for (ValveAction action : history) {
                writer.append(String.valueOf(action.getId()));
                writer.append(",");
                writer.append(String.valueOf(action.getUserId()));
                writer.append(",");
                writer.append(action.getAction());
                writer.append(",");
                writer.append(action.getTimestamp().toString());
                writer.append("\n");
            }
        }
    }
}
