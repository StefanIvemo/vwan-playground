param tenantId string = 'd259a616-4e9d-4615-b83d-2e09a6636fd4'

output login string = '${environment().authentication.loginEndpoint}${tenantId}/'
