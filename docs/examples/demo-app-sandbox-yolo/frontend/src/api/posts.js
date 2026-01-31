/**
 * API client for blog posts
 */

import axios from 'axios';

const API_BASE = '/api';

/**
 * Validate and sanitize ID parameter to prevent path traversal attacks
 * @param {*} id - The ID to validate
 * @returns {number} - Validated numeric ID
 * @throws {Error} - If ID is invalid
 */
function validateId(id) {
  // Convert to number and validate
  const numericId = parseInt(id, 10);

  // Check if it's a valid positive integer
  if (isNaN(numericId) || numericId <= 0 || !Number.isInteger(numericId)) {
    throw new Error(`Invalid ID: must be a positive integer, got ${id}`);
  }

  // Additional check: ensure original value doesn't contain path traversal characters
  const idString = String(id);
  if (idString.includes('..') || idString.includes('/') || idString.includes('\\')) {
    throw new Error(`Invalid ID: contains path traversal characters`);
  }

  return numericId;
}

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
    const validId = validateId(id);
    const response = await axios.get(`${API_BASE}/posts/${validId}`);
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
    const validId = validateId(id);
    const response = await axios.put(`${API_BASE}/posts/${validId}`, updates);
    return response.data;
  },

  /**
   * Delete a post
   */
  async deletePost(id) {
    const validId = validateId(id);
    await axios.delete(`${API_BASE}/posts/${validId}`);
  }
};
