import { useState, useEffect } from 'react';
import { postsAPI } from '../api/posts';

export default function PostDetail({ postId, onBack, onEdit, onDelete }) {
  const [post, setPost] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadPost();
  }, [postId]);

  const loadPost = async () => {
    try {
      setLoading(true);
      const data = await postsAPI.getPost(postId);
      setPost(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this post?')) {
      try {
        await postsAPI.deletePost(postId);
        onDelete();
      } catch (err) {
        alert('Failed to delete post: ' + err.message);
      }
    }
  };

  if (loading) return <div style={{ padding: '20px' }}>Loading...</div>;
  if (error) return <div style={{ padding: '20px' }}>Error: {error}</div>;
  if (!post) return <div style={{ padding: '20px' }}>Post not found</div>;

  return (
    <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
      <button onClick={onBack} style={{ marginBottom: '20px', padding: '8px 16px', cursor: 'pointer' }}>
        ← Back to List
      </button>

      <article>
        <h1>{post.title}</h1>
        <div style={{ color: '#666', marginBottom: '20px' }}>
          By {post.author} • {post.view_count} views • {new Date(post.created_at).toLocaleDateString()}
        </div>

        <div style={{ lineHeight: '1.6', marginBottom: '30px' }}>
          {post.content.split('\n').map((paragraph, i) => (
            <p key={i}>{paragraph}</p>
          ))}
        </div>

        <div style={{ borderTop: '1px solid #ddd', paddingTop: '20px' }}>
          <button
            onClick={() => onEdit(post)}
            style={{ marginRight: '10px', padding: '10px 20px', cursor: 'pointer' }}
          >
            Edit Post
          </button>
          <button
            onClick={handleDelete}
            style={{ padding: '10px 20px', cursor: 'pointer', backgroundColor: '#dc3545', color: 'white', border: 'none' }}
          >
            Delete Post
          </button>
        </div>
      </article>
    </div>
  );
}
