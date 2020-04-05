package com.Rayfalling.middleware;

import java.io.File;
import java.io.IOException;

public class FileExt {

    /**
     * 创建文件和父目录
     * @param file 需要创建的文件对象
     * @return 仅当创建成功时返回true, 否则返回false
     * @throws IOException 创建文件失败
     */
    public static boolean CreateFileWithParentDir(File file) throws IOException {
        if (!file.exists()) {
            File fileParent = file.getParentFile();
            if (!fileParent.exists()) {
                if (fileParent.mkdirs()) {
                    return file.createNewFile();
                }
            } else {
                return file.createNewFile();
            }
        }
        return false;
    }
}
