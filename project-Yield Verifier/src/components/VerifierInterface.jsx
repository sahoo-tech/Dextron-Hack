import React, { useState } from 'react';
import { Card, CardContent, Grid, Typography, TextField, Button, Alert, Snackbar } from '@mui/material';
import { ethers } from 'ethers';

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

    try {
      setLoading(true);
      const signer = provider.getSigner();
      
      // Create contract instance
      const verifierABI = [
        "function updateMetrics(address strategy) external",
        "function strategyMetrics(address) external view returns (uint256 performanceScore, uint256 benchmarkYield, uint256 lastUpdateTime, uint256 totalYield, uint256 volatility, uint256 utilizationRatio, uint256 regressionSlope, uint256 regressionIntercept)"
      ];
      const verifierAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Local Hardhat deployment address
      const verifierContract = new ethers.Contract(verifierAddress, verifierABI, signer);
      
      // Call verify function
      const tx = await verifierContract.updateMetrics(protocolAddress);
      await tx.wait();
      
      // Get updated metrics
      const metrics = await verifierContract.strategyMetrics(protocolAddress);
      console.log('Updated metrics:', metrics);

      setNotification({
        open: true,
        message: 'Protocol verification completed successfully!',
        severity: 'success'
      });
    } catch (error) {
      setNotification({
        open: true,
        message: error.message || 'Error verifying protocol',
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