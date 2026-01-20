export async function onRequest(context) {
  const url = new URL(context.request.url);

  // The subdomain you want to route specifically
  const TARGET_SUBDOMAIN = "blog.tinhkyaw.com";
  // The subdirectory content you want to serve at the root of the subdomain
  const TARGET_PATH = "/articles/";

  if (url.hostname === TARGET_SUBDOMAIN) {
    // If the path is the root, rewrite it to fetch the /articles/ page
    if (url.pathname === "/" || url.pathname === "") {
        url.pathname = TARGET_PATH;
        // We use env.ASSETS.fetch to get the static asset associated with the new path
        return context.env.ASSETS.fetch(url);
    }

    // Optional: If you want to strictly keep the user on the subdomain
    // when they navigate to other /articles/ pages, you might need more complex rewrites.
    // For now, this handles the entry point.
  }

  // Check for any other logic or just pass through
  return context.next();
}
