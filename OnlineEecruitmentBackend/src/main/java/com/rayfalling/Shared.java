package com.rayfalling;

import io.vertx.rxjava.core.Vertx;
import io.reactiverse.rxjava.pgclient.PgPool;
import io.vertx.rxjava.core.http.HttpServer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Shared {
    private static Logger logger;
    private static Vertx vertx;
    private static HttpServer httpServer;

    private static Shared instance = new Shared();

    /**
     * 工程 Postgresql 数据库连接池对象
     */
    private static PgPool pgPool;

    //让构造函数为 private，这样该类就不会被实例化
    private Shared() {
        logger = LogManager.getLogger();
        vertx = Vertx.vertx();
    }

    //获取唯一可用的对象
    public static Shared getInstance() {
        return instance;
    }

    public Logger getLogger() {
        return logger;
    }

    public Vertx getVertx() {
        return vertx;
    }

    public PgPool getPgPool() {
        return pgPool;
    }

    public HttpServer getHttpServer() {
        return httpServer;
    }

    public void setPgPool(PgPool pgPool) {
        Shared.pgPool = pgPool;
    }

    public void setHttpServer(HttpServer httpServer) {
        Shared.httpServer = httpServer;
    }
}
