const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

let cachedCredentials = null;

/**
 * Retrieves database credentials.
 * In AWS production: Reads securely from AWS Secrets Manager using IAM role credentials.
 * In local development: Falls back to environment variables.
 */
async function getDatabaseCredentials() {
  if (cachedCredentials) {
    return cachedCredentials;
  }

  const secretName = process.env.SECRET_NAME || 'bm_db_credentials';
  const region = process.env.AWS_REGION || 'us-east-1';
  const useSecretsManager = process.env.USE_SECRETS_MANAGER === 'true' || process.env.NODE_ENV === 'production';

  if (!useSecretsManager) {
    console.log('[Database] Using local environment configuration for database credentials');
    cachedCredentials = {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'bm_employees_db',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres'
    };
    return cachedCredentials;
  }

  console.log(`[Secrets Manager] Fetching database secret '${secretName}' from region '${region}'...`);
  try {
    const client = new SecretsManagerClient({ region });
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await client.send(command);

    if (!response.SecretString) {
      throw new Error('SecretString is empty in Secrets Manager response');
    }

    const secret = JSON.parse(response.SecretString);

    cachedCredentials = {
      host: secret.host || process.env.DB_HOST,
      port: parseInt(secret.port || process.env.DB_PORT || '5432', 10),
      database: secret.dbname || secret.database || process.env.DB_NAME || 'bm_employees_db',
      user: secret.username || secret.user,
      password: secret.password
    };

    console.log('[Secrets Manager] Successfully retrieved and cached database credentials.');
    return cachedCredentials;
  } catch (error) {
    console.error(`[Secrets Manager Error] Failed to retrieve secret '${secretName}':`, error.message);
    throw error;
  }
}

module.exports = {
  getDatabaseCredentials
};
