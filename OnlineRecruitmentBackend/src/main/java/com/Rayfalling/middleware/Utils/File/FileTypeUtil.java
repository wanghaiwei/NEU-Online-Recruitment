package com.Rayfalling.middleware.Utils.File;

import com.Rayfalling.Shared;
import io.reactivex.Single;
import io.vertx.reactivex.core.buffer.Buffer;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.stream.IntStream;

public class FileTypeUtil {
    static ArrayList<FileType> pictureFileType = new ArrayList<>(Arrays.asList(FileType.JPEG, FileType.PNG, FileType.GIF, FileType.BMP));
    
    private FileTypeUtil() {}
    
    /**
     * 得到上传文件的文件头
     *
     * @param src 字节流
     * @return String
     */
    private static @NotNull String bytesToHexString(byte[] src) {
        StringBuilder stringBuilder = new StringBuilder();
        if (null == src || src.length <= 0) {
            return "";
        }
        for (byte b : src) {
            int v = b & 0xFF;
            String hv = Integer.toHexString(v);
            if (hv.length() < 2) {
                stringBuilder.append(0);
            }
            stringBuilder.append(hv);
        }
        return stringBuilder.toString();
    }
    
    /**
     * 获取文件类型
     *
     * @param path 文件路径
     * @return 文件头
     */
    private Single<String> rxGetFileContent(String path) {
        return Shared.getVertx().fileSystem().rxReadFile(path).map(buffer -> {
            byte[] bytes = new byte[28];
            IntStream.range(0, bytes.length).forEach(i -> bytes[i] = buffer.getByte(i));
            return bytesToHexString(bytes);
        });
    }
    
    /**
     * 获取文件类型
     *
     * @param path 文件路径
     * @return 文件头
     */
    private @NotNull String getFileContent(String path) {
        byte[] bytes = new byte[28];
        Buffer buffer = Shared.getVertx().fileSystem().readFileBlocking(path);
        IntStream.range(0, bytes.length).forEach(i -> bytes[i] = buffer.getByte(i));
        return bytesToHexString(bytes);
    }
    
    /**
     * 获取文件类型
     *
     * @param path 文件路径
     * @return 文件类型
     */
    public Single<FileType> rxGetType(String path) {
        return rxGetFileContent(path).map(res -> {
            String fileHead = res.toUpperCase();
            if (fileHead.equals("") || fileHead.isEmpty()) return FileType.UNKNOWN;
            for (FileType fileType : FileType.values()) {
                if (fileHead.startsWith(fileType.getValue()))
                    return fileType;
            }
            return FileType.UNKNOWN;
        });
    }
    
    
    /**
     * 获取文件类型
     *
     * @param path 文件路径
     * @return 文件类型
     */
    public FileType getType(String path) {
        String fileHead = getFileContent(path).toUpperCase();
        if (fileHead.equals("") || fileHead.isEmpty()) return FileType.UNKNOWN;
        for (FileType fileType : FileType.values()) {
            if (fileHead.startsWith(fileType.getValue()))
                return fileType;
        }
        return FileType.UNKNOWN;
    }
    
    /**
     * 检查文件是否为图片格式
     *
     * @param path 文件路径
     * @return 是否为图片格式
     */
    public Single<Boolean> rxCheckIsPic(String path) {
        return rxGetType(path).map(result -> {
            if (result == null) return false;
            return pictureFileType.contains(result);
        });
    }
    
    /**
     * 检查文件是否为图片格式
     *
     * @param path 文件路径
     * @return 是否为图片格式
     */
    public Boolean checkIsPic(String path) {
        FileType fileType = getType(path);
        if (fileType == null) return false;
        return pictureFileType.contains(fileType);
    }
}
