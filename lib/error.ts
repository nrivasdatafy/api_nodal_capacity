export default class ErrorWithStatus extends Error {
  statusCode: number;

  constructor(message: string, statusCode: number) {
    super(message);

    this.statusCode = statusCode;
  }
}
