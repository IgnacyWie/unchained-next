export { default } from "next-auth/middleware";

export const config = {
  // Add the routes you want to protect here
  // The middleware checks for a valid session cookie automatically
  matcher: ["/dashboard/:path*", "/settings/:path*"],
};
