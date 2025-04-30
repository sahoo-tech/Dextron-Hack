import React from 'react';
import { Backdrop, CircularProgress, Typography, Box } from '@mui/material';

const LoadingOverlay = ({ open }) => {
  return (
    <Backdrop
      sx={{
        color: '#fff',
        zIndex: (theme) => theme.zIndex.drawer + 1,
        background: 'rgba(0, 0, 0, 0.8)',
        backdropFilter: 'blur(4px)'
      }}
      open={open}
    >
      <Box sx={{ textAlign: 'center' }}>
        <CircularProgress color="primary" size={60} thickness={4} />
        <Typography
          variant="h6"
          sx={{
            mt: 2,
            color: '#fff',
            textShadow: '0 2px 4px rgba(0,0,0,0.5)'
          }}
        >
          Processing...
        </Typography>
      </Box>
    </Backdrop>
  );
};

export default LoadingOverlay;