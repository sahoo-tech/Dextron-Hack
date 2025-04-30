import React from 'react';
import { AppBar, Toolbar, Typography, Button, Box } from '@mui/material';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';

const Header = ({ account }) => {
  const shortenAddress = (address) => {
    return address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '';
  };

  return (
    <AppBar position="static" sx={{ background: 'transparent', boxShadow: 'none' }}>
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Yield Verifier
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <AccountBalanceWalletIcon />
          <Button
            color="inherit"
            variant="outlined"
            sx={{
              borderRadius: 2,
              textTransform: 'none',
              '&:hover': {
                backgroundColor: 'rgba(255, 255, 255, 0.1)'
              }
            }}
          >
            {account ? shortenAddress(account) : 'Connect Wallet'}
          </Button>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;