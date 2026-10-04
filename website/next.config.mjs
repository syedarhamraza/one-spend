/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  images: { unoptimized: true },
  trailingSlash: true,
  // Captures and logos live in the Flutter repo; scripts/assets.mjs copies them in.
  outputFileTracingRoot: import.meta.dirname,
};

export default nextConfig;
