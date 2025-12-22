import { useState } from 'react';
import { postsAPI } from '../api/posts';

export default function PostForm({ post, onSave, onCancel }) {
  const [title, setTitle] = useState(post?.title || '');
  const [content, setContent] = useState(post?.content || '');
  const [author, setAuthor] = useState(post?.author || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const isEditing = !!post;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);

    if (!title.trim() || !content.trim() || !author.trim()) {
      setError('All fields are required');
      return;
    }

    try {
      setSaving(true);
      if (isEditing) {
        await postsAPI.updatePost(post.id, { title, content, author });
      } else {
        await postsAPI.createPost({ title, content, author });
      }
      onSave();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ padding: '20px', maxWidth: '600px', margin: '0 auto' }}>
      <h1>{isEditing ? 'Edit Post' : 'Create New Post'}</h1>

      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: '15px' }}>
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
            Title
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            style={{ width: '100%', padding: '8px', fontSize: '16px' }}
            required
          />
        </div>

        <div style={{ marginBottom: '15px' }}>
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
            Author
          </label>
          <input
            type="text"
            value={author}
            onChange={(e) => setAuthor(e.target.value)}
            style={{ width: '100%', padding: '8px', fontSize: '16px' }}
            required
          />
        </div>

        <div style={{ marginBottom: '15px' }}>
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
            Content
          </label>
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            style={{ width: '100%', padding: '8px', fontSize: '16px', minHeight: '200px' }}
            required
          />
        </div>

        {error && (
          <div style={{ color: 'red', marginBottom: '15px' }}>
            Error: {error}
          </div>
        )}

        <div>
          <button
            type="submit"
            disabled={saving}
            style={{ marginRight: '10px', padding: '10px 20px', cursor: 'pointer' }}
          >
            {saving ? 'Saving...' : (isEditing ? 'Update Post' : 'Create Post')}
          </button>
          <button
            type="button"
            onClick={onCancel}
            style={{ padding: '10px 20px', cursor: 'pointer' }}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
