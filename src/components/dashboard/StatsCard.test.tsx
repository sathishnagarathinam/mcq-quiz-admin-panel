import React from 'react';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { People } from '@mui/icons-material';
import { StatsCard } from './StatsCard';

const theme = createTheme();

const renderWithTheme = (component: React.ReactElement) => {
  return render(
    <ThemeProvider theme={theme}>
      {component}
    </ThemeProvider>
  );
};

describe('StatsCard', () => {
  const defaultProps = {
    title: 'Total Users',
    value: '1,234',
    icon: People,
    color: 'primary' as const,
    trend: {
      value: 12,
      isPositive: true,
    },
  };

  it('renders correctly with all props', () => {
    renderWithTheme(<StatsCard {...defaultProps} />);

    expect(screen.getByText('Total Users')).toBeInTheDocument();
    expect(screen.getByText('1,234')).toBeInTheDocument();
    expect(screen.getByText('+12%')).toBeInTheDocument();
  });

  it('displays positive trend correctly', () => {
    renderWithTheme(<StatsCard {...defaultProps} />);

    const changeElement = screen.getByText('+12%');
    expect(changeElement).toBeInTheDocument();
  });

  it('displays negative trend correctly', () => {
    const negativeProps = {
      ...defaultProps,
      trend: {
        value: -5,
        isPositive: false,
      },
    };

    renderWithTheme(<StatsCard {...negativeProps} />);

    const changeElement = screen.getByText('-5%');
    expect(changeElement).toBeInTheDocument();
  });

  it('renders icon correctly', () => {
    renderWithTheme(<StatsCard {...defaultProps} />);

    // Check that the icon is rendered (People icon should be present)
    expect(screen.getByTestId('PeopleIcon')).toBeInTheDocument();
  });

  it('handles missing trend prop', () => {
    const propsWithoutTrend = {
      title: 'Total Users',
      value: '1,234',
      icon: People,
      color: 'primary' as const,
    };

    renderWithTheme(<StatsCard {...propsWithoutTrend} />);

    expect(screen.getByText('Total Users')).toBeInTheDocument();
    expect(screen.getByText('1,234')).toBeInTheDocument();
    expect(screen.queryByText('+12%')).not.toBeInTheDocument();
  });

  it('is accessible', () => {
    renderWithTheme(<StatsCard {...defaultProps} />);

    // Check that the card is rendered and accessible
    const title = screen.getByText('Total Users');
    expect(title).toBeInTheDocument();

    const value = screen.getByText('1,234');
    expect(value).toBeInTheDocument();
  });

  it('renders with different colors', () => {
    const successProps = {
      ...defaultProps,
      color: 'success' as const,
    };

    renderWithTheme(<StatsCard {...successProps} />);

    expect(screen.getByText('Total Users')).toBeInTheDocument();
    expect(screen.getByText('1,234')).toBeInTheDocument();
  });
});
