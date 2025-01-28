package com.jxim.flutter_app_update.utils;

import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.channels.FileChannel;

public class FileHelps {
    //文件拷贝
    public static boolean copy(String fromFile, String toFile) {
        InputStream fosfrom = null;
        OutputStream fosto = null;
        try {
            fosfrom = new FileInputStream(fromFile);
            fosto = new FileOutputStream(toFile);
            byte[] bt = new byte[1024];
            int c;
            while ((c = fosfrom.read(bt)) > 0) {
                fosto.write(bt, 0, c);
            }
            fosfrom.close();
            fosto.close();
            return true;
        } catch (Exception ex) {
            if (fosfrom != null) {
                try {
                    fosfrom.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (fosto != null) {
                try {
                    fosto.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            return false;
        }
    }

    public static long getFileSize(String filePath){
        FileChannel fc= null;
        long fileSize = 0;
        try {
            File f= new File(filePath);
            if (f.exists() && f.isFile()){
                FileInputStream fis= new FileInputStream(f);
                fc= fis.getChannel();
                fileSize = fc.size();
            }else{
                Log.e("getFileSize","file doesn't exist or is not a file");
            }
        } catch (FileNotFoundException e) {
            Log.e("getFileSize",e.getMessage());
        } catch (IOException e) {
            Log.e("getFileSize",e.getMessage());
        } finally {
            if (null!=fc){
                try{
                    fc.close();
                }catch(IOException e){
                    Log.e("getFileSize",e.getMessage());
                }
            }
        }
        return fileSize;
    }
}
