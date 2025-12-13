import { render, screen, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import PostList from '../PostList';
import { postsAPI } from '../../api/posts';

// Mock the API
vi.mock('../../api/posts', () => ({
  postsAPI: {
    getPosts: vi.fn(),
  },
}));

describe('PostList', () => {
  const mockOnSelectPost = vi.fn();
  const mockOnCreateNew = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('renders loading state initially', () => {
    postsAPI.getPosts.mockImplementation(() => new Promise(() => {}));
    render(<PostList onSelectPost={mockOnSelectPost} onCreateNew={mockOnCreateNew} />);
    expect(screen.getByText(/loading posts/i)).toBeInTheDocument();
  });

  test('renders posts when loaded', async () => {
    const mockPosts = [
      {
        id: 1,
        title: 'Test Post 1',
        author: 'Author 1',
        view_count: 10,
        created_at: '2024-01-01T00:00:00',
      },
      {
        id: 2,
        title: 'Test Post 2',
        author: 'Author 2',
        view_count: 20,
        created_at: '2024-01-02T00:00:00',
      },
    ];

    postsAPI.getPosts.mockResolvedValue(mockPosts);

    render(<PostList onSelectPost={mockOnSelectPost} onCreateNew={mockOnCreateNew} />);

    await waitFor(() => {
      expect(screen.getByText('Test Post 1')).toBeInTheDocument();
      expect(screen.getByText('Test Post 2')).toBeInTheDocument();
    });
  });

  test('renders empty state when no posts', async () => {
    postsAPI.getPosts.mockResolvedValue([]);

    render(<PostList onSelectPost={mockOnSelectPost} onCreateNew={mockOnCreateNew} />);

    await waitFor(() => {
      expect(screen.getByText(/no posts yet/i)).toBeInTheDocument();
    });
  });

  test('renders error state on API failure', async () => {
    postsAPI.getPosts.mockRejectedValue(new Error('API Error'));

    render(<PostList onSelectPost={mockOnSelectPost} onCreateNew={mockOnCreateNew} />);

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});
