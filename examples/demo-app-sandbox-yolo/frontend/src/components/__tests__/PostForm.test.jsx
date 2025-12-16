import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import PostForm from '../PostForm';
import { postsAPI } from '../../api/posts';

// Mock the API
vi.mock('../../api/posts', () => ({
  postsAPI: {
    createPost: vi.fn(),
    updatePost: vi.fn(),
  },
}));

describe('PostForm', () => {
  const mockOnSave = vi.fn();
  const mockOnCancel = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('renders create form when no post provided', () => {
    render(<PostForm onSave={mockOnSave} onCancel={mockOnCancel} />);
    expect(screen.getByText('Create New Post')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /create post/i })).toBeInTheDocument();
  });

  test('renders edit form when post provided', () => {
    const mockPost = {
      id: 1,
      title: 'Existing Post',
      content: 'Existing content',
      author: 'Test Author',
    };

    render(<PostForm post={mockPost} onSave={mockOnSave} onCancel={mockOnCancel} />);
    expect(screen.getByText('Edit Post')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Existing Post')).toBeInTheDocument();
  });

  test('validates required fields', async () => {
    render(<PostForm onSave={mockOnSave} onCancel={mockOnCancel} />);

    const submitButton = screen.getByRole('button', { name: /create post/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/all fields are required/i)).toBeInTheDocument();
    });
    expect(mockOnSave).not.toHaveBeenCalled();
  });

  test('creates post successfully', async () => {
    postsAPI.createPost.mockResolvedValue({ id: 1 });

    render(<PostForm onSave={mockOnSave} onCancel={mockOnCancel} />);

    fireEvent.change(screen.getByLabelText(/title/i), {
      target: { value: 'New Title' },
    });
    fireEvent.change(screen.getByLabelText(/author/i), {
      target: { value: 'New Author' },
    });
    fireEvent.change(screen.getByLabelText(/content/i), {
      target: { value: 'New content' },
    });

    const submitButton = screen.getByRole('button', { name: /create post/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(postsAPI.createPost).toHaveBeenCalledWith({
        title: 'New Title',
        content: 'New content',
        author: 'New Author',
      });
      expect(mockOnSave).toHaveBeenCalled();
    });
  });

  test('calls onCancel when cancel button clicked', () => {
    render(<PostForm onSave={mockOnSave} onCancel={mockOnCancel} />);

    const cancelButton = screen.getByRole('button', { name: /cancel/i });
    fireEvent.click(cancelButton);

    expect(mockOnCancel).toHaveBeenCalled();
  });
});
