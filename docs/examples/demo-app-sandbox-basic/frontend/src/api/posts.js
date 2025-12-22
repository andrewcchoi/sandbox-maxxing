/**
 * API client for blog posts
 */

import axios from 'axios';

const API_BASE = '/api';

export const postsAPI = {
  /**
   * Get all posts
   */
  async getPosts() {
    const response = await axios.get(`${API_BASE}/posts`);
    return response.data;
  },

  /**
   * Get a single post by ID
   */
  async getPost(id) {
    const response = await axios.get(`${API_BASE}/posts/${id}`);
    return response.data;
  },

  /**
   * Create a new post
   */
  async createPost(post) {
    const response = await axios.post(`${API_BASE}/posts`, post);
    return response.data;
  },

  /**
   * Update a post
   */
  async updatePost(id, updates) {
    const response = await axios.put(`${API_BASE}/posts/${id}`, updates);
    return response.data;
  },

  /**
   * Delete a post
   */
  async deletePost(id) {
    await axios.delete(`${API_BASE}/posts/${id}`);
  }
};
