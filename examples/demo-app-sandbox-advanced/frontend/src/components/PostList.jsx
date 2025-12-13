import { useState, useEffect } from 'react';
import { postsAPI } from '../api/posts';

export default function PostList({ onSelectPost, onCreateNew }) {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadPosts();
  }, []);

  const loadPosts = async () => {
    try {
      setLoading(true);
      const data = await postsAPI.getPosts();
      setPosts(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading posts...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div style={{ padding: '20px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <h1>Blog Posts</h1>
        <button onClick={onCreateNew} style={{ padding: '10px 20px', cursor: 'pointer' }}>
          Create New Post
        </button>
      </div>

      {posts.length === 0 ? (
        <p>No posts yet. Create your first post!</p>
      ) : (
        <div>
          {posts.map(post => (
            <div
              key={post.id}
              onClick={() => onSelectPost(post.id)}
              style={{
                border: '1px solid #ddd',
                borderRadius: '8px',
                padding: '15px',
                marginBottom: '15px',
                cursor: 'pointer',
                transition: 'box-shadow 0.2s',
              }}
              onMouseEnter={(e) => e.currentTarget.style.boxShadow = '0 2px 8px rgba(0,0,0,0.1)'}
              onMouseLeave={(e) => e.currentTarget.style.boxShadow = 'none'}
            >
              <h2 style={{ margin: '0 0 10px 0' }}>{post.title}</h2>
              <p style={{ color: '#666', margin: '5px 0' }}>
                By {post.author} • {post.view_count} views
              </p>
              <p style={{ color: '#999', fontSize: '0.9em' }}>
                {new Date(post.created_at).toLocaleDateString()}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
