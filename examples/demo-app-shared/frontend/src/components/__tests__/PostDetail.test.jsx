import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import PostDetail from '../PostDetail';
import { postsAPI } from '../../api/posts';

// Mock the API
vi.mock('../../api/posts', () => ({
  postsAPI: {
    getPost: vi.fn(),
    deletePost: vi.fn(),
  },
}));

describe('PostDetail', () => {
  const mockOnBack = vi.fn();
  const mockOnEdit = vi.fn();
  const mockOnDelete = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    // Mock window.confirm and window.alert
    global.confirm = vi.fn();
    global.alert = vi.fn();
  });

  test('renders loading state initially', () => {
    postsAPI.getPost.mockImplementation(() => new Promise(() => {}));
    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  test('renders post details when loaded', async () => {
    const mockPost = {
      id: 1,
      title: 'Test Post Title',
      content: 'Test post content with multiple lines.\nSecond paragraph here.',
      author: 'Test Author',
      view_count: 42,
      created_at: '2024-01-15T12:00:00',
    };

    postsAPI.getPost.mockResolvedValue(mockPost);

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Test Post Title')).toBeInTheDocument();
    });

    expect(screen.getByText(/Test Author/)).toBeInTheDocument();
    expect(screen.getByText(/42 views/)).toBeInTheDocument();
    expect(screen.getByText('Test post content with multiple lines.')).toBeInTheDocument();
    expect(screen.getByText('Second paragraph here.')).toBeInTheDocument();
  });

  test('renders error state on API failure', async () => {
    postsAPI.getPost.mockRejectedValue(new Error('Network error'));

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });

  test('calls onBack when back button clicked', async () => {
    const mockPost = {
      id: 1,
      title: 'Test Post',
      content: 'Content',
      author: 'Author',
      view_count: 10,
      created_at: '2024-01-15T12:00:00',
    };

    postsAPI.getPost.mockResolvedValue(mockPost);

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Test Post')).toBeInTheDocument();
    });

    const backButton = screen.getByRole('button', { name: /back to list/i });
    fireEvent.click(backButton);

    expect(mockOnBack).toHaveBeenCalled();
  });

  test('calls onEdit with post when edit button clicked', async () => {
    const mockPost = {
      id: 1,
      title: 'Test Post',
      content: 'Content',
      author: 'Author',
      view_count: 10,
      created_at: '2024-01-15T12:00:00',
    };

    postsAPI.getPost.mockResolvedValue(mockPost);

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Test Post')).toBeInTheDocument();
    });

    const editButton = screen.getByRole('button', { name: /edit post/i });
    fireEvent.click(editButton);

    expect(mockOnEdit).toHaveBeenCalledWith(mockPost);
  });

  test('deletes post when delete button clicked and confirmed', async () => {
    const mockPost = {
      id: 1,
      title: 'Test Post',
      content: 'Content',
      author: 'Author',
      view_count: 10,
      created_at: '2024-01-15T12:00:00',
    };

    postsAPI.getPost.mockResolvedValue(mockPost);
    postsAPI.deletePost.mockResolvedValue();
    global.confirm.mockReturnValue(true);

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Test Post')).toBeInTheDocument();
    });

    const deleteButton = screen.getByRole('button', { name: /delete post/i });
    fireEvent.click(deleteButton);

    await waitFor(() => {
      expect(postsAPI.deletePost).toHaveBeenCalledWith(1);
      expect(mockOnDelete).toHaveBeenCalled();
    });
  });

  test('does not delete post when delete is cancelled', async () => {
    const mockPost = {
      id: 1,
      title: 'Test Post',
      content: 'Content',
      author: 'Author',
      view_count: 10,
      created_at: '2024-01-15T12:00:00',
    };

    postsAPI.getPost.mockResolvedValue(mockPost);
    global.confirm.mockReturnValue(false);

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Test Post')).toBeInTheDocument();
    });

    const deleteButton = screen.getByRole('button', { name: /delete post/i });
    fireEvent.click(deleteButton);

    expect(postsAPI.deletePost).not.toHaveBeenCalled();
    expect(mockOnDelete).not.toHaveBeenCalled();
  });

  test('shows alert on delete failure', async () => {
    const mockPost = {
      id: 1,
      title: 'Test Post',
      content: 'Content',
      author: 'Author',
      view_count: 10,
      created_at: '2024-01-15T12:00:00',
    };

    postsAPI.getPost.mockResolvedValue(mockPost);
    postsAPI.deletePost.mockRejectedValue(new Error('Delete failed'));
    global.confirm.mockReturnValue(true);

    render(
      <PostDetail
        postId={1}
        onBack={mockOnBack}
        onEdit={mockOnEdit}
        onDelete={mockOnDelete}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Test Post')).toBeInTheDocument();
    });

    const deleteButton = screen.getByRole('button', { name: /delete post/i });
    fireEvent.click(deleteButton);

    await waitFor(() => {
      expect(global.alert).toHaveBeenCalledWith('Failed to delete post: Delete failed');
    });

    expect(mockOnDelete).not.toHaveBeenCalled();
  });
});
