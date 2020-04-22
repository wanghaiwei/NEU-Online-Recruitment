package com.Rayfalling.handler;

import com.Rayfalling.Shared;
import io.reactiverse.reactivex.pgclient.PgConnection;
import io.reactivex.Single;

public class DatabaseConnection {
    public static Single<PgConnection> PgConnectionSingle() {
        return Shared.getPgPool().rxGetConnection().doOnError(err -> {
            Shared.getDatabaseLogger().error(err);
            err.printStackTrace();
        }).doAfterSuccess(PgConnection::close).doOnError(err -> {
            Shared.getDatabaseLogger().error(err);
            err.printStackTrace();
        });
    }
}
