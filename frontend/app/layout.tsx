import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: "Nora",
  description: "Nora — robotics build log, blog, and design plans",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header className="site-header">
          <nav>
            <Link href="/" className="brand">
              Nora
            </Link>
            <Link href="/blog">Blog</Link>
            <Link href="/design-plans">Design Plans</Link>
          </nav>
        </header>
        <main>{children}</main>
      </body>
    </html>
  );
}
