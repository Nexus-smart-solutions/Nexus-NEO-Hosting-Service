**Workspaces**
```
GET    http://18.191.180.43:8080/api/terraform/workspaces
POST   http://18.191.180.43:8080/api/terraform/workspaces
GET    http://18.191.180.43:8080/api/terraform/workspaces/{name}
PATCH  http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}
DELETE http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}
```

**Runs**
```
GET  http://18.191.180.43:8080/api/terraform/runs/{runId}
POST http://18.191.180.43:8080/api/terraform/runs/{runId}/apply
POST http://18.191.180.43:8080/api/terraform/runs/{runId}/discard
POST http://18.191.180.43:8080/api/terraform/runs/{runId}/cancel
```

**Workspace Runs**
```
GET  http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/runs
POST http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/runs
```

**Variables**
```
GET    http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables
POST   http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables
PATCH  http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables/{variableId}
DELETE http://18.191.180.43:8080/api/terraform/workspaces/{workspaceId}/variables/{variableId}
