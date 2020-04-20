package com.Rayfalling.middleware.Extensions;

import io.reactiverse.reactivex.pgclient.Row;
import io.vertx.core.json.JsonObject;

public interface MapJsonArray {
    JsonObject map(Row row);
}
