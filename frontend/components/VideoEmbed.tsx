const YOUTUBE_ID =
  /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|shorts\/))([A-Za-z0-9_-]{11})/;

export default function VideoEmbed({ url }: { url?: string }) {
  if (!url) return null;
  const match = url.match(YOUTUBE_ID);
  if (!match) {
    return (
      <p>
        <a href={url} target="_blank" rel="noreferrer">
          Watch video
        </a>
      </p>
    );
  }
  return (
    <div className="video-embed">
      <iframe
        src={`https://www.youtube-nocookie.com/embed/${match[1]}`}
        title="Video"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen
      />
    </div>
  );
}
