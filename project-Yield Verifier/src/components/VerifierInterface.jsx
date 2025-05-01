import React, { useState } from 'react';
import { Card, CardContent, Grid, Typography, TextField, Button, Alert, Snackbar } from '@mui/material';
import { ethers } from 'ethers';
import { getContract } from '../contracts/config';

const VerifierInterface = ({ provider, setLoading }) => {
  const [protocolAddress, setProtocolAddress] = useState('');
  const [notification, setNotification] = useState({ open: false, message: '', severity: 'info' });

  const handleVerify = async () => {
    if (!provider || !protocolAddress) {
      setNotification({
        open: true,
        message: 'Please connect wallet and enter protocol address',
        severity: 'warning'
      });
      return;
    }

    if (!ethers.utils.isAddress(protocolAddress)) {
      setNotification({
        open: true,
        message: 'Invalid protocol address format',
        severity: 'error'
      });
      return;
    }

    try {
      setLoading(true);
      const signer = provider.getSigner();
      
      // Get contract instance
      const verifierContract = getContract('YieldVerifier', signer);
      
      // Call verify function
      const tx = await verifierContract.updateMetrics(protocolAddress);
      setNotification({
        open: true,
        message: 'Verification in progress...',
        severity: 'info'
      });

      await tx.wait();
      
      // Get updated metrics
      const metrics = await verifierContract.strategyMetrics(protocolAddress);
      const { performanceScore, benchmarkYield, totalYield, volatility } = metrics;

      setNotification({
        open: true,
        message: `Verification successful! Performance Score: ${ethers.utils.formatUnits(performanceScore, 18)}`,
        severity: 'success'
      });
    } catch (error) {
      let errorMessage = 'Error verifying protocol';
      
      if (error.code === 'INVALID_ARGUMENT') {
        errorMessage = 'Invalid protocol address';
      } else if (error.code === 'UNPREDICTABLE_GAS_LIMIT') {
        errorMessage = 'Contract execution failed - check protocol status';
      } else if (error.code === 'CALL_EXCEPTION') {
        errorMessage = 'Contract call failed - verify protocol address';
      }

      setNotification({
        open: true,
        message: errorMessage,
        severity: 'error'
      });
    } finally {
      setLoading(false);
    }
  };

  const handleCloseNotification = () => {
    setNotification(prev => ({ ...prev, open: false }));
  };

  return (
    <Card sx={{ background: 'rgba(255, 255, 255, 0.05)', backdropFilter: 'blur(10px)' }}>
      <CardContent>
        <Typography variant="h5" gutterBottom sx={{ color: '#fff' }}>
          Verify Protocol
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <TextField
              fullWidth
              label="Protocol Address"
              value={protocolAddress}
              onChange={(e) => setProtocolAddress(e.target.value)}
              sx={{
                '& .MuiOutlinedInput-root': {
                  '& fieldset': {
                    borderColor: 'rgba(255, 255, 255, 0.23)'
                  },
                  '&:hover fieldset': {
                    borderColor: 'rgba(255, 255, 255, 0.5)'
                  },
                  '&.Mui-focused fieldset': {
                    borderColor: '#2196f3'
                  }
                },
                '& .MuiInputLabel-root': {
                  color: 'rgba(255, 255, 255, 0.7)'
                },
                '& .MuiInputBase-input': {
                  color: '#fff'
                }
              }}
            />
          </Grid>
          <Grid item xs={12} md={4}>
            <Button
              fullWidth
              variant="contained"
              onClick={handleVerify}
              disabled={!protocolAddress}
              sx={{
                height: '56px',
                background: 'linear-gradient(45deg, #2196f3 30%, #21cbf3 90%)',
                transition: 'all 0.3s ease-in-out',
                '&:hover': {
                  background: 'linear-gradient(45deg, #1976d2 30%, #00bcd4 90%)',
                  transform: 'translateY(-2px)',
                  boxShadow: '0 4px 8px rgba(33, 150, 243, 0.3)'
                },
                '&:disabled': {
                  background: 'rgba(255, 255, 255, 0.12)',
                  color: 'rgba(255, 255, 255, 0.3)'
                }
              }}
            >
              Verify Protocol
            </Button>
          </Grid>
        </Grid>
      </CardContent>
      <Snackbar
        open={notification.open}
        autoHideDuration={6000}
        onClose={handleCloseNotification}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          onClose={handleCloseNotification}
          severity={notification.severity}
          variant="filled"
          sx={{ width: '100%' }}
        >
          {notification.message}
        </Alert>
      </Snackbar>
    </Card>
  );
};

export default VerifierInterface;