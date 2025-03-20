export type SimpleObject = { [key: string]: any };

export type WebTokenPayload = {
  _id: any;
};

export type BackendConfig = {
  port: number;
};

export type TokenEnv = {
  prod: string;
  rest: string;
};

export type TokensConfig = {
  externals: {
    externalApi: TokenEnv;
    prodTechApi: TokenEnv;
  };
  jwtSecret: TokenEnv;
};

export interface BasicEntity {
  _id: any;
}
