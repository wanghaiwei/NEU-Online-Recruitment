package com.Rayfalling.router;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.router.User.AuthRouter;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.file.FileSystem;
import io.vertx.reactivex.ext.web.FileUpload;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;


/**
 * 上传文件处理类
 */
public class UploadRouter {
    private static final Router router = Router.router(Shared.getVertx());
    static String uploadPrefix = "upload/";
    
    //静态初始化块
    static {
        String prefix = "/api/upload";
        
        router.get("/").handler(UploadRouter::UploadIndex);
        
        /* 不需要鉴权的路由 */
        router.get("/:type/:year/:month/:filename").handler(UploadRouter::SendFile);
        
        /* 需要鉴权的路由 */
        router.post("/new").handler(AuthRouter::AuthToken).handler(UploadRouter::Upload);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    /**
     * 防止根目录泄露
     */
    private static void UploadIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of upload router.").trim());
    }
    
    /**
     * 提供静态文件
     */
    @SuppressWarnings({"ResultOfMethodCallIgnored"})
    private static void SendFile(@NotNull RoutingContext context) {
        Single.just(context.request()).map(param -> "upload/" + param.getParam("type") +
                                                    "/" + param.getParam("year") +
                                                    "/" + param.getParam("month") +
                                                    "/" + param.getParam("filename"))
              .doOnError(err -> JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_GET_PARAM))
              .flatMapCompletable(param -> context.response().rxSendFile(param))
              .doOnError(err -> JsonResponse.RespondPreset(context, PresetMessage.ERROR_FILE_NOT_FOUND))
              .subscribe(() -> {
                  Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
              }, failure -> {
                  Shared.getRouterLogger().error(failure.getMessage());
              });
    }
    
    /**
     * 处理文件上传
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void Upload(@NotNull RoutingContext context) {
        Single.just(context).map(param -> param.request().getParam("type")).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(type -> {
            Set<FileUpload> files = context.fileUploads();
            Map<String, String> fileList = new HashMap<>();
            for (FileUpload fileUpload : files) {
                String dirPath = uploadPrefix + String.format("%s/%s/%s/", type,
                        LocalDate.now().getYear(), LocalDate.now().getMonth().getValue());
                String path = dirPath + fileUpload.fileName();
                FileSystem fileSystem = Shared.getVertx().fileSystem();
                Shared.getVertx().fileSystem().rxExists(dirPath).map(res -> {
                    if (!res)
                        return fileSystem.rxMkdirs(dirPath).doOnComplete(() -> {
                            fileSystem.rxMove(fileUpload.uploadedFileName(), path).doOnComplete(() -> {
                                fileSystem.rxDelete(fileUpload.uploadedFileName());
                            }).subscribe();
                        }).subscribe();
                    else
                        return fileSystem.rxMove(fileUpload.uploadedFileName(), path).doOnComplete(() -> {
                            fileSystem.rxDelete(fileUpload.uploadedFileName());
                        }).subscribe();
                }).subscribe(res -> {
                    Shared.getRouterLogger().info("Upload file " + path + " successfully");
                }, failure -> {
                    Shared.getRouterLogger().error(failure.getMessage());
                });
                fileList.put(fileUpload.name(), path);
            }
            JsonResponse.RespondJson(context, new JsonObject().put("filepath", fileList));
            
            return Single.just(fileList);
        }).doOnError(err -> {
            JsonResponse.RespondPreset(context, PresetMessage.ERROR_UPLOAD_FAILED);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
