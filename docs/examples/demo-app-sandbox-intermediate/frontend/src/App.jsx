import { useState } from 'react';
import PostList from './components/PostList';
import PostDetail from './components/PostDetail';
import PostForm from './components/PostForm';

function App() {
  const [view, setView] = useState('list'); // 'list', 'detail', 'create', 'edit'
  const [selectedPostId, setSelectedPostId] = useState(null);
  const [editingPost, setEditingPost] = useState(null);

  const handleSelectPost = (postId) => {
    setSelectedPostId(postId);
    setView('detail');
  };

  const handleCreateNew = () => {
    setEditingPost(null);
    setView('create');
  };

  const handleEdit = (post) => {
    setEditingPost(post);
    setView('edit');
  };

  const handleBack = () => {
    setView('list');
    setSelectedPostId(null);
    setEditingPost(null);
  };

  const handleSave = () => {
    setView('list');
    setSelectedPostId(null);
    setEditingPost(null);
  };

  const handleDelete = () => {
    setView('list');
    setSelectedPostId(null);
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
      <header style={{ backgroundColor: '#fff', borderBottom: '1px solid #ddd', padding: '15px 20px' }}>
        <h1 style={{ margin: 0 }} onClick={handleBack} style={{ cursor: 'pointer' }}>
          📝 Demo Blog Platform
        </h1>
        <p style={{ margin: '5px 0 0 0', color: '#666', fontSize: '0.9em' }}>
          Claude Code Sandbox Example
        </p>
      </header>

      <main>
        {view === 'list' && (
          <PostList
            onSelectPost={handleSelectPost}
            onCreateNew={handleCreateNew}
          />
        )}

        {view === 'detail' && (
          <PostDetail
            postId={selectedPostId}
            onBack={handleBack}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        )}

        {(view === 'create' || view === 'edit') && (
          <PostForm
            post={editingPost}
            onSave={handleSave}
            onCancel={handleBack}
          />
        )}
      </main>
    </div>
  );
}

export default App;
