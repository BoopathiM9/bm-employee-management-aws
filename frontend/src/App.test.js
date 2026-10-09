import { render, screen } from '@testing-library/react';
import App from '../src/App';

test('renders login page title when unauthenticated', () => {
  render(<App />);
  const titleElement = screen.getByText(/BM Portal/i);
  expect(titleElement).toBeInTheDocument();
  const signinButton = screen.getByRole('button', { name: /Sign In/i });
  expect(signinButton).toBeInTheDocument();
});
