import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  SvgIconProps
} from '@mui/material';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: React.ComponentType<SvgIconProps>;
  color?: 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';
  trend?: {
    value: number;
    isPositive: boolean;
  };
}

export const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  icon: Icon,
  color = 'primary',
  trend
}) => {
  return (
    <Card
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        overflow: 'visible',
        '&:hover': {
          transform: 'translateY(-2px)',
          transition: 'transform 0.2s ease-in-out',
          boxShadow: (theme) => theme.shadows[8],
        },
      }}
    >
      <CardContent sx={{ flexGrow: 1, pb: 2 }}>
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            mb: 2,
          }}
        >
          <Typography
            variant="h6"
            component="h3"
            color="text.secondary"
            sx={{ fontSize: '0.875rem', fontWeight: 500 }}
          >
            {title}
          </Typography>
          <Box
            sx={{
              p: 1,
              borderRadius: 2,
              backgroundColor: (theme) => 
                color === 'primary' ? theme.palette.primary.light :
                color === 'secondary' ? theme.palette.secondary.light :
                color === 'success' ? theme.palette.success.light :
                color === 'warning' ? theme.palette.warning.light :
                color === 'error' ? theme.palette.error.light :
                theme.palette.info.light,
              color: (theme) => 
                color === 'primary' ? theme.palette.primary.contrastText :
                color === 'secondary' ? theme.palette.secondary.contrastText :
                color === 'success' ? theme.palette.success.contrastText :
                color === 'warning' ? theme.palette.warning.contrastText :
                color === 'error' ? theme.palette.error.contrastText :
                theme.palette.info.contrastText,
            }}
          >
            <Icon sx={{ fontSize: 24 }} />
          </Box>
        </Box>

        <Typography
          variant="h4"
          component="div"
          sx={{
            fontWeight: 700,
            mb: 1,
            color: 'text.primary',
          }}
        >
          {typeof value === 'number' ? value.toLocaleString() : value}
        </Typography>

        {trend && (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 0.5,
            }}
          >
            <Typography
              variant="body2"
              sx={{
                color: trend.isPositive ? 'success.main' : 'error.main',
                fontWeight: 600,
              }}
            >
              {trend.isPositive ? '+' : ''}{trend.value}%
            </Typography>
            <Typography
              variant="body2"
              color="text.secondary"
            >
              from last month
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};
